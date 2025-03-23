// 加载头部和底部组件
document.addEventListener('DOMContentLoaded', function() {
    // 加载头部
    const headerPlaceholder = document.getElementById('header-placeholder');
    if (headerPlaceholder) {
        fetch('header.html')
            .then(response => response.text())
            .then(data => {
                headerPlaceholder.innerHTML = data;
                
                // 高亮当前页面的导航链接
                const currentPage = window.location.pathname.split('/').pop();
                let navId = 'nav-home'; // 默认
                
                if (currentPage === '' || currentPage === 'index.html') navId = 'nav-home';
                else if (currentPage === 'tutorials.html') navId = 'nav-tutorials';
                else if (currentPage === 'faq.html') navId = 'nav-faq';
                else if (currentPage === 'contact.html') navId = 'nav-contact';
                else if (currentPage === 'privacy.html') navId = 'nav-privacy';
                
                // 对于教程详情页面
                if (currentPage.startsWith('tutorial-')) navId = 'nav-tutorials';
                
                const activeLink = document.getElementById(navId);
                if (activeLink) activeLink.classList.add('active');
            })
            .catch(error => {
                console.error('加载头部失败:', error);
                headerPlaceholder.innerHTML = '<p>加载导航失败。请刷新页面重试。</p>';
            });
    }
    
    // 加载底部
    const footerPlaceholder = document.getElementById('footer-placeholder');
    if (footerPlaceholder) {
        fetch('footer.html')
            .then(response => response.text())
            .then(data => {
                footerPlaceholder.innerHTML = data;
            })
            .catch(error => {
                console.error('加载底部失败:', error);
                footerPlaceholder.innerHTML = '<p>加载页脚失败。请刷新页面重试。</p>';
            });
    }
});