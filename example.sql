--lista restauracji oferujujacych dostawe do dzielnicy {x}
select nazwa_res from rest_dziel rd
join restauracja r on rd.id_res = r.id_res
join dzielnica d on rd.id_dz=d.id_dz
where nazwa_dz='Ursynów';

--jak wy¿ej, z wykorzystaniem rankingu ocen i sortowaniem wzglêdem niego, 
--ograniczajac liczbe pozycji do {y}
select rownum Pozycja, "Restauracja", "Œrednia ocen" from
    (select "Restauracja", "Œrednia ocen" from view_ranking_ocen
    where "Restauracja" in (select nazwa_res from rest_dziel rd
        join restauracja r on rd.id_res = r.id_res
        join dzielnica d on rd.id_dz=d.id_dz
        where nazwa_dz='Ursynów')
    order by "Œrednia ocen" desc)
where rownum <=3;


--lista restauracji z kategorii {x} oferujujacych dostawe do dzielnicy {y}
select nazwa_res "Restauracja" from rest_dziel rd
join restauracja r on rd.id_res = r.id_res
join dzielnica d on rd.id_dz=d.id_dz
join kat_res kr on r.id_res = kr.id_res
join kategoria_res kres on kr.id_kat_res=kres.id_kat_res
where nazwa_dz='Ursynów' and nazwa_kat_res='Wegetariañskie';


--lista kategorii z iloœcia restauracji z nimi zwiazana
select nazwa_kat_res Restauracja, count(kat_res.id_kat_res) Ilosc from kat_res
join kategoria_res on kat_res.id_kat_res=kategoria_res.id_kat_res
group by nazwa_kat_res
order by count(kat_res.id_kat_res) desc;


--historia zamowien klienta, od najnowszego
select distinct data_zam Data, nazwa_res Restauracja,
(select sum(ilosc) from zam_prod join
    zamowienie on zam_prod.id_zam=zamowienie.id_zam
    where id_kl=9) "Ilosc produktow",
(select sum(ilosc*cena_prod) from zam_prod join 
    zamowienie on zam_prod.id_zam=zamowienie.id_zam
    join produkt on zam_prod.id_prod=produkt.id_prod
    where id_kl=9) "Koszt", nazwa_plat "Sposób platnosci"
from zam_prod zp join zamowienie z on zp.id_zam=z.id_zam
join restauracja r on z.id_res = r.id_res
join sposob_platnosci sp on z.id_plat = sp.id_plat
where id_kl=9 
order by Data;




    
 
   
