create sequence seq_skladnik
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table skladnik
modify id_skl default seq_skladnik.nextval;

create sequence seq_restauracja
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table restauracja
modify id_res default seq_restauracja.nextval;

create sequence seq_ocena
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table ocena
modify id_oc default seq_ocena.nextval;

create sequence seq_klient
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table klient
modify id_kl default seq_klient.nextval;

create sequence seq_produkt
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table produkt
modify id_prod default seq_produkt.nextval;

create sequence seq_zamowienie
increment by 1
start with 1
maxvalue 999999999999
minvalue 1
cache 20;
alter table zamowienie
modify id_zam default seq_zamowienie.nextval;


create or replace trigger tr_skl_prod
before insert or delete or update on skl_prod
for each row
begin
    if INSERTING then
        update produkt
            set waga=waga+:new.waga_skl
        where id_prod = :new.id_prod;
        update produkt
            set kalorie=kalorie+:new.waga_skl/100*(select kalorie_na_sto_gram
            from skladnik where id_skl=:new.id_skl)
        where id_prod = :new.id_prod;
    end if;
    if UPDATING then
        update produkt
            set waga=waga+:new.waga_skl-:old.waga_skl
        where id_prod = :new.id_prod; --:new tożsame z :old, klucze glowne nie beda zmieniane 
        update produkt                --update zmienia jedynie wagę
            set kalorie=kalorie+(:new.waga_skl/100 - :old.waga_skl/100)*(select kalorie_na_sto_gram
            from skladnik where id_skl=:new.id_skl)
        where id_prod = :new.id_prod;
    end if;
    if DELETING then
        update produkt
            set waga=waga-:old.waga_skl
        where id_prod = :old.id_prod;
        update produkt
            set kalorie=kalorie-:old.waga_skl/100*(select kalorie_na_sto_gram
            from skladnik where id_skl=:old.id_skl)
        where id_prod = :old.id_prod;
    end if;
end;
/


CREATE OR REPLACE VIEW VIEW_ZAMOWIENIA_KTO_ILE AS 
select zm.id_res as ID, nazwa_res as Restauracja, data_zam as Data,imie ||' '|| nazwisko as Klient,telefon_kl as Telefon,
adres_kl as Adres, sum(cena_prod*ilosc) as Kwota, nazwa_plat as Platnosc
from zamowienie zm
join klient k on zm.id_kl=k.id_kl
join restauracja r on zm.id_res = r.id_res
join sposob_platnosci s on zm.id_plat = s.id_plat
join zam_prod zp on zp.id_zam=zm.id_zam
join produkt p on p.id_prod=zp.id_prod
group by data_zam,imie,nazwisko,telefon_kl,nazwa_plat,adres_kl,zm.id_res, nazwa_res
order by data_zam;

CREATE OR REPLACE VIEW VIEW_ZAMOWIENIA_CO_ILE AS 
select zp.id_zam "ID",data_zam Data, nazwa_res Restauracja, nazwa_prod Pozycja, adres_res, telefon_res,
imie ||' '|| nazwisko Klient,adres_kl, telefon_kl,
ilosc Ilosc, cena_prod Cena, ilosc*cena_prod Koszt, nazwa_plat Platnosc
from zam_prod zp
join produkt p on zp.id_prod = p.id_prod
join restauracja r on p.id_res=r.id_res
join zamowienie zam on zp.id_zam = zam.id_zam
join klient k on zam.id_kl=k.id_kl
join sposob_platnosci sp on zam.id_plat = sp.id_plat;

create or replace view view_ranking_ocen as
select nazwa_res Restauracja, round(avg(ocena),2) "Średnia ocen" 
from restauracja r
join ocena o on r.id_res=o.id_res
group by nazwa_res
order by "Średnia ocen" desc;

CREATE OR REPLACE VIEW VIEW_MENU AS 
select produkt.id_res as Id, nazwa_res as Restauracja, nazwa_kat_prod as Kategoria, nazwa_prod as Pozycja, cena_prod as Cena
from produkt
join kategoria_prod on produkt.id_kat_prod=kategoria_prod.id_kat_prod
join restauracja on produkt.id_res=restauracja.id_res;

create or replace view view_oceny_restauracji as
select id_res id,ocena Ocena, opis_oc Opis, imie Imie, nazwisko Nazwisko, telefon_kl Telefon
from ocena oc
join klient kl on oc.id_kl=kl.id_kl
order by ocena;

CREATE OR REPLACE VIEW VIEW_SKLAD AS 
select sp.id_prod id, nazwa_skl Skladnik, round(tluszcze*waga_skl/100,2) Tluszcze, 
round(weglowodany*waga_skl/100,2) Weglowodany, 
round(bialko*waga_skl/100,2) Bialko, waga_skl Waga, round(kalorie_na_sto_gram*waga_skl/100,2) Kalorie
from skl_prod sp
join skladnik s on sp.id_skl=s.id_skl
join produkt p on sp.id_prod = p.id_prod
order by kalorie desc;


create or replace function fn_zysk_okres
                            (v_id_res number, v_pocz date, v_koniec date)
return number
as
    v_zysk number(10);
begin
    select sum(ilosc*cena_prod) into v_zysk from zam_prod zp
    join produkt p on zp.id_prod = p.id_prod
    join zamowienie z on zp.id_zam = z.id_zam
    where z.id_res=v_id_res and data_zam between v_pocz and v_koniec;
return v_zysk;
end;
/

create or replace function fn_najtansza_restauracja
                        (v_id_dz number)
return number
as
    v_id_res number(4);
begin
    select id_res into v_id_res from restauracja
    where id_res =
        (select id_res from 
            (select rownum lp, id_res from
                (select sl.id_res, avg(cena_prod) cena from 
                (select id_res from rest_dziel where id_dz=v_id_dz) sl
                join produkt p on sl.id_res=p.id_res
                group by sl.id_res
                order by cena)
            where rownum=1)
        where lp=1);
return v_id_res;
end;
/

create or replace function fn_czy_klient_zamowil_z
                                (v_id_res number, v_id_kl number)
return boolean
as
v_licznik number(3);
begin
    select count(zp.id_zam) into v_licznik from zam_prod zp
    join zamowienie z on zp.id_zam=z.id_zam
    join produkt p on zp.id_prod = p.id_prod
    join restauracja r on r.id_res = p.id_res
    where r.id_res=v_id_res and id_kl=v_id_kl;
    
    if v_licznik=0 then return false;
    else return true;
    end if;
end;
/

create or replace procedure pr_czy_klient_zamowil_z
                                (v_id_res number, v_id_kl number)
as
v_imie varchar2(12);
v_nazwisko varchar2(20);
v_nazwa_res varchar2(30);
begin 
    select nazwa_res into v_nazwa_res from restauracja where id_res=v_id_res;
    select imie, nazwisko into v_imie, v_nazwisko from klient where id_kl = v_id_kl;
    if fn_czy_klient_zamowil_z(v_id_res, v_id_kl)
        then dbms_output.put_line(v_imie||' '||v_nazwisko||' witamy ponownie w '||v_nazwa_res);
    elsif not fn_czy_klient_zamowil_z(v_id_res, v_id_kl) then
        dbms_output.put_line(v_imie||' '||v_nazwisko||' witamy w '||v_nazwa_res||'. Przygotowalismy dla Ciebie znizki na pierwsze zamowienie');
    end if;
end;
/


create or replace procedure pr_insert_ocena
                        (v_ocena number,
                         v_id_res number,
                         v_id_kl number,
                         v_opis varchar2 default null)
as
v_nazwa_res varchar2(30);
begin
    select nazwa_res into v_nazwa_res from restauracja where id_res=v_id_res;
    if fn_czy_klient_zamowil_z(v_id_res, v_id_kl) then 
        insert into ocena(ocena, opis_oc, id_res, id_kl) values(v_ocena, v_opis, v_id_res, v_id_kl);
        dbms_output.put_line('Wystawiono pomyslnie ocene '||v_ocena||' restauracji '||v_nazwa_res);
    elsif not fn_czy_klient_zamowil_z(v_id_res, v_id_kl) then
       dbms_output.put_line('Aby wystawic ocene restauracji musisz z niej cos najpierw zamowic!');
       end if;
end;
/






